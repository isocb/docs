API Credentials
Client ID
clt_SNHRbI6ttrOckf925lbaX

Your organization identifier. This is automatically included when using your API key - no need to send it in API requests.

API Key
Generate API Key
Generate an API key to enable external integrations and API access.

API Documentation
User Creation Endpoint
Create new users in your organization using the API. Users are created directly with passwords and can log in immediately.

POST
/api/users
API Payload → User Table Mapping
Payload Field
Database Column
Required
Description
clientId
clientId
Auto-derived from API key (not needed in payload)
email
email
User's email address (must be unique)
displayName
displayName
User's full name
password
passwordHash
User's password (minimum 8 characters)
role
role
User role: "clientUser" or "clientAdmin" (default: "clientUser")
emailFilteringEnabled
emailFilteringEnabled
Email filtering setting (default: true)
Example Request
curl -X POST https://your-domain.com/_api/client/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "email": "john.doe@example.com",
    "displayName": "John Doe",
    "password": "securepassword123",
    "role": "clientUser",
    "emailFilteringEnabled": true
  }'
Key Points
Authentication: Include your API key in the Authorization header as a Bearer token
Automatic Client ID: The API key automatically identifies your organization - no need to include clientId in the payload
Direct User Creation: Users are created immediately with the provided password - no email invitations
Immediate Access: Users can log in right away using their email and the password you provided
Role Restrictions: Only "clientUser" or "clientAdmin" roles are allowed for new users
Permission Model: New users inherit your organization's settings and restrictions
Password Requirements: Passwords must be at least 8 characters long
Duplicate Prevention: Email addresses must be unique across the entire platform
Security: Store passwords securely - they are hashed before being saved to the database
Zapier Integration
Easily create users from Zapier workflows using the Webhooks by Zapier action:

Copy your API key from the credentials section above
In Zapier, create a "Webhooks by Zapier" action
Select POST as the method
Enter the URL: https://your-domain.com/_api/client/users
Header Configuration
In Zapier's "Headers" section, add TWO headers using the two-part form. Each header has a Label (the header name) and Content (the header value):

Header 1:
Label: Content-Type
Content: application/json
Header 2:
Label: Authorization
Content: Bearer [your-api-key-here]
⚠️ Common Mistake:
Do NOT put "Bearer" in the Label field! The word "Bearer" must be part of the Content field, followed by a space and your API key.
❌ WRONG:
Label: Bearer
Content: bdk_c789...
✅ CORRECT:
Label: Authorization
Content: Bearer bdk_c789...
JSON Payload
Configure the data payload with your user information:

{
  "email": "{{trigger_email}}",
  "displayName": "{{trigger_name}}",
  "password": "{{trigger_password}}",
  "role": "clientUser",
  "emailFilteringEnabled": true
}
Test your webhook to verify the configuration
Activate your Zap

Note: Replace {{trigger_email}}, {{trigger_name}}, and {{trigger_password}} with the appropriate field names from your trigger step.

Zapier Integration
Setup Instructions:
Copy your Client ID and API key from the credentials section above
In Zapier, create a new "Webhooks by Zapier" action
Configure the webhook to use the same user creation API endpoint:
Method: POST
URL: https://your-domain.com/_api/client/users
Content-Type: application/json
Add the Authorization header: Bearer [your-api-key]
Configure the JSON payload with required fields (including password):
{
  "clientId": "clt_SNHRbI6ttrOckf925lbaX",
  "email": "{{user_email}}",
  "displayName": "{{user_name}}",
  "password": "{{user_password}}",
  "role": "clientUser",
  "emailFilteringEnabled": true
}
Test the integration and activate your Zap
Pro Tips:
Password Management: Ensure you have a secure way to generate and communicate passwords to users
Immediate Access: Users can log in right away once created - plan your user communication accordingly
Use Zapier's formatter to clean email addresses and names before sending
Set up filters to prevent duplicate user creation
Consider using Zapier's delay feature for bulk operations
Monitor your Zapier task usage as each user creation counts as one task