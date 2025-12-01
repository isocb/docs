# IsoStack UX Patterns

This document outlines the core user experience patterns used throughout IsoStack.  These patterns create a consistent, intuitive interface that reduces cognitive load and accelerates user workflows.

---

## 🎯 Core Principle: Click-to-View-and-Edit

**Philosophy:** Viewing and editing should be the same action. Don't make users hunt for edit buttons or navigate through multiple screens.

### Pattern: Modal-Based CRUD

**Used in:** Issue Tracker, (future: all entity management)

#### The Pattern

1. **List View** - Cards or table rows display entity summaries
2. **Click Anywhere** - Entire card/row is clickable (large target)
3. **Modal Opens** - Shows full details in edit mode immediately
4. **Inline Actions** - Critical actions available without opening modal (badges for status/priority)
5. **Modal Actions** - Full edit capabilities + Delete button
6. **Click Outside** - Closes modal (ESC key also works)

#### Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│  MODAL TITLE                                         ✕  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  [Form fields for editing]                              │
│  [Rich text editor]                                      │
│  [Tag selectors, etc.]                                   │
│                                                          │
│  ┌────────────┐                    ┌────────┐ ┌────────┐│
│  │ 🗑️ Delete  │                    │ Cancel │ │  Save  ││
│  └────────────┘                    └────────┘ └────────┘│
│  (Red, left)                       (Right side actions) │
└─────────────────────────────────────────────────────────┘
```

#### Benefits

- ✅ **Huge Click Target** - Entire card is clickable (easier than tiny icons)
- ✅ **Faster Workflow** - One click to view details AND edit
- ✅ **Reduced Cognitive Load** - No "view mode" vs "edit mode" distinction
- ✅ **Mobile Friendly** - Large touch targets
- ✅ **Accessible** - Keyboard navigation (Tab, ESC, Enter)
- ✅ **Consistent** - Same pattern everywhere

#### Implementation Example

```typescript
// Issue card is fully clickable
<Card 
  onClick={() => openModal(issue)}
  style={{ cursor: 'pointer' }}
>
  <Title>{issue.title}</Title>
  <Text>{preview}</Text>
  
  {/* Quick actions - stop propagation to prevent modal opening */}
  <Badge 
    onClick={(e) => {
      e.stopPropagation();
      markComplete(issue.id);
    }}
  >
    Mark Complete
  </Badge>
</Card>

// Modal with delete button on left
<Modal>
  <Group justify="space-between">
    <Button color="red" onClick={handleDelete}>
      Delete
    </Button>
    <Group>
      <Button variant="subtle" onClick={close}>Cancel</Button>
      <Button type="submit">Save</Button>
    </Group>
  </Group>
</Modal>
```

---

## 🔄 Pattern: Inline Quick Actions

**Used in:** Issue List badges

### The Pattern

For frequently used actions (status changes, priority adjustments), provide **inline controls** that work without opening the modal.

#### Example: Issue Status Badges

- Badge shows current status ("Open", "In Progress", "Complete")
- Click badge → Dropdown appears
- Select new status → Updates immediately
- Visual feedback (toast notification)
- **Event propagation stopped** - Doesn't trigger card click

#### Benefits

- ⚡ **Speed** - Change status without opening modal
- 🎯 **Precision** - Small actions don't need big modals
- 🔀 **Flexibility** - Users choose quick action OR full edit

---

## 🎨 Pattern: Progressive Disclosure

**Philosophy:** Show what's necessary, hide complexity until needed. 

### Visual Hierarchy

1. **Card Level** - Title, key metadata, truncated description
2. **Badge Level** - Status, priority, category (clickable for quick change)
3. **Modal Level** - Full details, all edit capabilities, delete action

### Information Density

```
CARD VIEW (List)
├── Essential only: Title, status, priority, tags
├── Truncated description (2-3 lines max)
└── Created date & author

MODAL VIEW (Detail)
├── All fields editable
├── Full rich text description
├── Complete tag management
└── Delete option
```

---

## 🎭 Pattern: Dangerous Actions

**Philosophy:** Destructive actions should be visually distinct and require confirmation.

### Delete Button Placement

- **Position:** Bottom-left of modal (opposite from Save)
- **Color:** Red (`color="red"`)
- **Icon:** Trash icon
- **Confirmation:** Always require confirmation dialog
- **Text:** "Delete" (clear, not "Remove" or "Erase")

### Confirmation Dialog

```typescript
if (! confirm(`Delete issue "${title}"? This cannot be undone. `)) {
  return;
}
```

- **Clear consequence:** "This cannot be undone"
- **Entity name shown:** User knows exactly what they're deleting
- **Native dialog:** Fast, accessible, familiar

---

## 📱 Mobile Considerations

All patterns are mobile-first:

- ✅ Large click targets (min 44×44px)
- ✅ Full-width cards on small screens
- ✅ Modal fills screen on mobile
- ✅ Touch-friendly spacing
- ✅ Swipe gestures (future enhancement)

---

## ♿ Accessibility

- ✅ **Keyboard Navigation:** Tab through cards, Enter to open, ESC to close
- ✅ **Screen Readers:** Proper ARIA labels, semantic HTML
- ✅ **Focus Management:** Focus returns to card after modal closes
- ✅ **Color Contrast:** All text meets WCAG AA standards
- ✅ **Focus Indicators:** Visible focus rings on interactive elements

---

## 🚀 Future Patterns

### Drag-and-Drop Reordering
- Drag cards to reorder
- Visual feedback during drag
- Snap to position on drop

### Bulk Actions
- Select multiple cards (checkbox appears on hover)
- Action bar appears at top
- Apply status/tag/delete to multiple items

### Keyboard Shortcuts
- `N` - New issue
- `? ` - Show keyboard shortcuts
- `/ ` - Focus search/filter
- `ESC` - Close modal/clear selection

---

## 📐 Design Tokens

### Spacing
- Card padding: `lg` (16px)
- Gap between cards: `md` (12px)
- Modal padding: `xl` (20px)

### Typography
- Card title: `order={4}` (H4)
- Card description: `0.875rem`
- Modal title: `order={2}` (H2)

### Colors
- Delete: `red` (Mantine red palette)
- Success: `green`
- Warning: `yellow`
- Info: `blue`

### Transitions
- Hover effect: `box-shadow 0.2s ease`
- Modal: Mantine defaults (fade + scale)
- Toast: Mantine defaults (slide from top)

---

## 🎯 When to Use This Pattern

✅ **Use for:**
- Entity management (issues, tasks, documents)
- User profiles
- Settings pages
- Content editing

❌ **Don't use for:**
- Wizards (multi-step processes)
- Dashboards (overview, not editing)
- Reports (read-only data)
- Login/signup flows

---

## 🧪 Testing Checklist

When implementing this pattern:

- [ ] Entire card is clickable
- [ ] Hover effect provides visual feedback
- [ ] Modal opens with all fields populated
- [ ] Delete button is bottom-left, red, with icon
- [ ] Cancel button is bottom-right
- [ ] Save/Update button is rightmost
- [ ] Click outside modal closes it
- [ ] ESC key closes modal
- [ ] Inline badges have `stopPropagation()`
- [ ] Confirmation required for delete
- [ ] Toast notifications for all actions
- [ ] Loading states on buttons
- [ ] Form validation works
- [ ] Keyboard navigation works
- [ ] Mobile responsive

---

## 📚 Related Documentation

- [Component Library](../components/README.md)
- [Mantine UI Guidelines](https://mantine.dev/)
- [Accessibility Standards](./accessibility.md)

---

**Last Updated:** 2025-01-26  
**Pattern Owner:** Platform Architecture Team