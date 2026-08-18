# Feature Spec: Sample Counter

Demonstration feature that implements a persistent increment counter.

## 1. User Stories / Use Cases
* As a user, I want to click an increment button to increase the counter value by 1.
* As a user, I want to prevent the counter from exceeding 100 (business rule).
* As a user, I want my count changes to persist offline and automatically sync with the server when connection is restored (optional sync queue).

## 2. Data Entities & Screens
* **Entity**: `CounterRecord` (id, value, updatedAt)
* **Screens**: Counter Screen (`SMP-02`)

## 3. Dependencies
* Depends on core database providers (`lib/core/database/`).
* Depends on core networking base API client (`lib/core/network/`).

## 4. Safety & Security
* Max value of 100 must be verified on both the domain use case (client preview) and remote server checks.
