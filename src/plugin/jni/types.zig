const std = @import("std");

pub const GetStringUTFChars_t = fn (*JNIEnv, jstring, *bool) [*:0]const u8;
pub const GetStringUTFLength_t = fn (*JNIEnv, jstring) usize;

pub const JNINativeInterface = extern struct {
    reserved0: ?*anyopaque = null,
    reserved1: ?*anyopaque = null,
    reserved2: ?*anyopaque = null,
    reserved3: ?*anyopaque = null,

    GetStringUTFChars: ?*const fn (*JNIEnv, jstring, *bool) callconv(.C) [*:0]const u8 = null,
    GetStringUTFLength: ?*const fn (*JNIEnv, jstring) callconv(.C) usize = null,
    // Add other JNI functions as needed
};

pub const JNIEnv = *JNINativeInterface;
pub const JavaVM = *anyopaque;
pub const jclass = jobject;
pub const jobject = ?*anyopaque;
pub const jmethodID = ?*anyopaque;
pub const jfieldID = ?*anyopaque;
pub const jstring = jobject;
pub const jarray = ?*anyopaque;
pub const jobjectArray = jobject;
pub const jboolean = u8;
pub const jbyte = i8;
pub const jchar = u16;
pub const jshort = i16;
pub const jint = i32;
pub const jlong = i64;
pub const jfloat = f32;
pub const jdouble = f64;
pub const jsize = jint;
pub const jvalue = extern union {
    z: jboolean,
    b: jbyte,
    c: jchar,
    s: jshort,
    i: jint,
    j: jlong,
    f: jfloat,
    d: jdouble,
    l: jobject,
};

pub const JNI_TRUE: jboolean = 1;
pub const JNI_FALSE: jboolean = 0;

pub const JNI_OK = 0;
pub const JNI_ERR = -1;
pub const JNI_EDETACHED = -2;
pub const JNI_EVERSION = -3;
pub const JNI_ENOMEM = -4;
pub const JNI_EEXIST = -5;
pub const JNI_EINVAL = -6;

pub const JNI_VERSION_1_1: jint = 0x00010001;
pub const JNI_VERSION_1_2: jint = 0x00010002;
pub const JNI_VERSION_1_4: jint = 0x00010004;
pub const JNI_VERSION_1_6: jint = 0x00010006;
pub const JNI_VERSION_1_8: jint = 0x00010008;
pub const JNI_VERSION_9: jint = 0x00090000;
pub const JNI_VERSION_10: jint = 0x000a0000;
