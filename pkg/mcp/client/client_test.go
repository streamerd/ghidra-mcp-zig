package main

import (
	"bufio"
	"encoding/json"
	"net"
	"strconv"
	"testing"
	"time"
)

// Mock server for testing
type mockServer struct {
	listener  net.Listener
	responses map[string]Response
}

func newMockServer(t *testing.T) *mockServer {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Failed to create mock server: %v", err)
	}

	server := &mockServer{
		listener: listener,
		responses: map[string]Response{
			"decompile": {
				Status: "success",
				Data:   json.RawMessage(`{"decompiled": "int main() { return 0; }"}`),
			},
			"rename_function": {
				Status: "success",
				Data:   json.RawMessage(`{"message": "Function renamed successfully"}`),
			},
			"rename_data": {
				Status: "success",
				Data:   json.RawMessage(`{"message": "Data renamed successfully"}`),
			},
			"list_functions": {
				Status: "success",
				Data:   json.RawMessage(`[{"address": 4096, "name": "main"}]`),
			},
			"list_data": {
				Status: "success",
				Data:   json.RawMessage(`[{"address": 8192, "name": "data"}]`),
			},
			"list_imports": {
				Status: "success",
				Data:   json.RawMessage(`[{"name": "printf", "library": "libc"}]`),
			},
			"list_exports": {
				Status: "success",
				Data:   json.RawMessage(`[{"name": "main", "address": 4096}]`),
			},
		},
	}

	go server.acceptConnections(t)

	return server
}

func (s *mockServer) acceptConnections(t *testing.T) {
	for {
		conn, err := s.listener.Accept()
		if err != nil {
			return
		}

		go s.handleConnection(conn, t)
	}
}

func (s *mockServer) handleConnection(conn net.Conn, t *testing.T) {
	defer conn.Close()

	reader := bufio.NewReader(conn)
	for {
		msg, err := reader.ReadString('\n')
		if err != nil {
			return
		}

		var message Message
		if err := json.Unmarshal([]byte(msg), &message); err != nil {
			t.Errorf("Failed to unmarshal message: %v", err)
			continue
		}

		response, ok := s.responses[message.Type]
		if !ok {
			response = Response{
				Status: "error",
				Data:   json.RawMessage(`{"error": "Unknown message type"}`),
			}
		}

		responseJSON, err := json.Marshal(response)
		if err != nil {
			t.Errorf("Failed to marshal response: %v", err)
			continue
		}

		if _, err := conn.Write(append(responseJSON, '\n')); err != nil {
			t.Errorf("Failed to write response: %v", err)
			return
		}
	}
}

func (s *mockServer) Close() {
	s.listener.Close()
}

func (s *mockServer) Addr() net.Addr {
	return s.listener.Addr()
}

func TestMCPClient(t *testing.T) {
	server := newMockServer(t)
	defer server.Close()

	addr := server.Addr().String()
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		t.Fatalf("Failed to split address: %v", err)
	}

	portNum, err := strconv.Atoi(port)
	if err != nil {
		t.Fatalf("Failed to parse port: %v", err)
	}

	config := &Config{
		Host:            host,
		Port:            portNum,
		Timeout:         5 * time.Second,
		MaxRetries:      3,
		RetryDelay:      100 * time.Millisecond,
		PrettyPrintJSON: false,
	}

	client := NewMCPClient(config)

	tests := []struct {
		name     string
		testFunc func(*testing.T)
	}{
		{"TestConnect", func(t *testing.T) {
			err := client.Connect()
			if err != nil {
				t.Errorf("Connect failed: %v", err)
			}
			client.Disconnect()
		}},
		{"TestDecompileFunction", func(t *testing.T) {
			resp, err := client.DecompileFunction(0x1000)
			if err != nil {
				t.Errorf("DecompileFunction failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestRenameFunction", func(t *testing.T) {
			resp, err := client.RenameFunction(0x1000, "new_main")
			if err != nil {
				t.Errorf("RenameFunction failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestRenameData", func(t *testing.T) {
			resp, err := client.RenameData(0x2000, "new_data")
			if err != nil {
				t.Errorf("RenameData failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestListFunctions", func(t *testing.T) {
			resp, err := client.ListFunctions()
			if err != nil {
				t.Errorf("ListFunctions failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestListData", func(t *testing.T) {
			resp, err := client.ListData()
			if err != nil {
				t.Errorf("ListData failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestListImports", func(t *testing.T) {
			resp, err := client.ListImports()
			if err != nil {
				t.Errorf("ListImports failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestListExports", func(t *testing.T) {
			resp, err := client.ListExports()
			if err != nil {
				t.Errorf("ListExports failed: %v", err)
			}
			if resp.Status != "success" {
				t.Errorf("Expected success status, got %s", resp.Status)
			}
		}},
		{"TestTimeout", func(t *testing.T) {
			// Test with a very short timeout
			config.Timeout = 1 * time.Millisecond
			client = NewMCPClient(config)
			_, err := client.DecompileFunction(0x1000)
			if err == nil {
				t.Error("Expected timeout error, got nil")
			}
		}},
		{"TestRetry", func(t *testing.T) {
			// Test with a server that fails once then succeeds
			config.MaxRetries = 3
			config.RetryDelay = 100 * time.Millisecond
			client = NewMCPClient(config)
			_, err := client.DecompileFunction(0x1000)
			if err != nil {
				t.Errorf("Expected success after retry, got %v", err)
			}
		}},
	}

	for _, tt := range tests {
		t.Run(tt.name, tt.testFunc)
	}
}
