--!strict
-- core/services.luau
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local cachedServices = {
	Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players"),
	RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService"),
	UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService"),
	TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService"),
	StarterGui = cloneref and cloneref(game:GetService("StarterGui")) or game:GetService("StarterGui"),
	Lighting = cloneref and cloneref(game:GetService("Lighting")) or game:GetService("Lighting"),
	TeleportService = cloneref and cloneref(game:GetService("TeleportService")) or game:GetService("TeleportService"),
	HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService"),
	ReplicatedStorage = cloneref and cloneref(game:GetService("ReplicatedStorage")) or game:GetService("ReplicatedStorage"),
	Workspace = cloneref and cloneref(game:GetService("Workspace")) or game:GetService("Workspace"),
	SoundService = cloneref and cloneref(game:GetService("SoundService")) or game:GetService("SoundService"),
}

ModMenu = ModMenu or {}
ModMenu.Services = cachedServices
ModMenu.LocalPlayer = cachedServices.Players.LocalPlayer
ModMenu.Camera = cachedServices.Workspace.CurrentCamera
