package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"time"
)

// Custom error types
type ConnectionError struct {
	Err error
}

func (e *ConnectionError) Error() string {
	return fmt.Sprintf("connection error: %v", e.Err)
}

type MessageError struct {
	Err error
}

func (e *MessageError) Error() string {
	return fmt.Sprintf("message error: %v", e.Err)
}

type ResponseError struct {
	Err error
}

func (e *ResponseError) Error() string {
	return fmt.Sprintf("response error: %v", e.Err)
}

// Configuration options
type Config struct {
	Host            string
	Port            int
	Timeout         time.Duration
	MaxRetries      int
	RetryDelay      time.Duration
	PrettyPrintJSON bool
}

func DefaultConfig() *Config {
	return &Config{
		Host:            "127.0.0.1",
		Port:            8080,
		Timeout:         30 * time.Second,
		MaxRetries:      3,
		RetryDelay:      1 * time.Second,
		PrettyPrintJSON: true,
	}
}

type MCPClient struct {
	config *Config
	conn   net.Conn
}

type Message struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data,omitempty"`
	ID   string          `json:"id,omitempty"`
}

type Response struct {
	Status string          `json:"status"`
	Data   json.RawMessage `json:"data"`
}

func NewMCPClient(config *Config) *MCPClient {
	if config == nil {
		config = DefaultConfig()
	}
	return &MCPClient{
		config: config,
	}
}

func (c *MCPClient) Connect() error {
	addr := fmt.Sprintf("%s:%d", c.config.Host, c.config.Port)
	conn, err := net.DialTimeout("tcp", addr, c.config.Timeout)
	if err != nil {
		return &ConnectionError{Err: fmt.Errorf("failed to connect to %s: %v", addr, err)}
	}
	c.conn = conn
	fmt.Printf("Connected to MCP server at %s\n", addr)
	return nil
}

func (c *MCPClient) Disconnect() {
	if c.conn != nil {
		c.conn.Close()
		c.conn = nil
	}
}

func (c *MCPClient) sendMessage(messageType string, data interface{}, messageID string) (*Response, error) {
	var lastErr error
	for retry := 0; retry <= c.config.MaxRetries; retry++ {
		if c.conn == nil {
			if err := c.Connect(); err != nil {
				lastErr = err
				time.Sleep(c.config.RetryDelay)
				continue
			}
		}

		msg := Message{
			Type: messageType,
			ID:   messageID,
		}

		if data != nil {
			dataJSON, err := json.Marshal(data)
			if err != nil {
				return nil, &MessageError{Err: fmt.Errorf("failed to marshal data: %v", err)}
			}
			msg.Data = dataJSON
		}

		msgJSON, err := json.Marshal(msg)
		if err != nil {
			return nil, &MessageError{Err: fmt.Errorf("failed to marshal message: %v", err)}
		}

		// Set write deadline
		if err := c.conn.SetWriteDeadline(time.Now().Add(c.config.Timeout)); err != nil {
			return nil, &ConnectionError{Err: fmt.Errorf("failed to set write deadline: %v", err)}
		}

		// Send message with newline
		if _, err := fmt.Fprintf(c.conn, "%s\n", msgJSON); err != nil {
			lastErr = &MessageError{Err: fmt.Errorf("failed to send message: %v", err)}
			c.Disconnect()
			time.Sleep(c.config.RetryDelay)
			continue
		}

		// Set read deadline
		if err := c.conn.SetReadDeadline(time.Now().Add(c.config.Timeout)); err != nil {
			return nil, &ConnectionError{Err: fmt.Errorf("failed to set read deadline: %v", err)}
		}

		// Read response
		reader := bufio.NewReader(c.conn)
		response, err := reader.ReadString('\n')
		if err != nil {
			lastErr = &ResponseError{Err: fmt.Errorf("failed to read response: %v", err)}
			c.Disconnect()
			time.Sleep(c.config.RetryDelay)
			continue
		}

		var resp Response
		if err := json.Unmarshal([]byte(response), &resp); err != nil {
			return nil, &ResponseError{Err: fmt.Errorf("failed to unmarshal response: %v", err)}
		}

		return &resp, nil
	}

	return nil, lastErr
}

func (c *MCPClient) DecompileFunction(address uint64) (*Response, error) {
	return c.sendMessage("decompile", map[string]uint64{"address": address}, "")
}

func (c *MCPClient) RenameFunction(address uint64, newName string) (*Response, error) {
	data := map[string]interface{}{
		"address":  address,
		"new_name": newName,
	}
	return c.sendMessage("rename_function", data, "")
}

func (c *MCPClient) RenameData(address uint64, newName string) (*Response, error) {
	data := map[string]interface{}{
		"address":  address,
		"new_name": newName,
	}
	return c.sendMessage("rename_data", data, "")
}

func (c *MCPClient) ListFunctions() (*Response, error) {
	return c.sendMessage("list_functions", nil, "")
}

func (c *MCPClient) ListData() (*Response, error) {
	return c.sendMessage("list_data", nil, "")
}

func (c *MCPClient) ListImports() (*Response, error) {
	return c.sendMessage("list_imports", nil, "")
}

func (c *MCPClient) ListExports() (*Response, error) {
	return c.sendMessage("list_exports", nil, "")
}

func main() {
	config := DefaultConfig()
	client := NewMCPClient(config)
	defer client.Disconnect()

	// Test decompilation
	fmt.Println("\nTesting decompilation:")
	if resp, err := client.DecompileFunction(0x1000); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		var prettyJSON []byte
		if config.PrettyPrintJSON {
			prettyJSON, _ = json.MarshalIndent(resp, "", "  ")
		} else {
			prettyJSON, _ = json.Marshal(resp)
		}
		fmt.Println(string(prettyJSON))
	}

	// Test function renaming
	fmt.Println("\nTesting function renaming:")
	if resp, err := client.RenameFunction(0x1000, "new_main"); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}

	// Test data renaming
	fmt.Println("\nTesting data renaming:")
	if resp, err := client.RenameData(0x2000, "new_data"); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}

	// Test listing functions
	fmt.Println("\nTesting function listing:")
	if resp, err := client.ListFunctions(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}

	// Test listing data
	fmt.Println("\nTesting data listing:")
	if resp, err := client.ListData(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}

	// Test listing imports
	fmt.Println("\nTesting import listing:")
	if resp, err := client.ListImports(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}

	// Test listing exports
	fmt.Println("\nTesting export listing:")
	if resp, err := client.ListExports(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
	} else {
		prettyJSON, _ := json.MarshalIndent(resp, "", "  ")
		fmt.Println(string(prettyJSON))
	}
}
