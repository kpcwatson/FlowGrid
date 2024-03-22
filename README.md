For creating a tag cloud like the following:

![image](https://github.com/kpcwatson/FlowGrid/assets/510515/44c8df47-3b86-4951-a27a-21fc1b8bb9dc)

Usage:
```swift
let items = [ ... ]
FlowGrid(spacing: 8, alignment: .leading) {
    ForEach(items, id: \.self) { item in
        Text(item)
            .padding(8)
            .border(.black, width: 1)
    }
}
```
