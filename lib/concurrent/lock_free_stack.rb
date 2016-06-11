module Concurrent
  class LockFreeStack < Synchronization::Object

    safe_initialization!

    class Node
      attr_reader :value, :next_node

      def initialize(value, next_node)
        @value     = value
        @next_node = next_node
      end

      singleton_class.send :alias_method, :[], :new
    end

    class Empty < Node
      def next_node
        self
      end
    end

    EMPTY = Empty[nil, nil]

    private(*attr_atomic(:head))

    def initialize
      super()
      self.head = EMPTY
    end

    def empty?(head = self.head)
      head.equal? EMPTY
    end

    def compare_and_push(head, value)
      compare_and_set_head head, Node[value, head]
    end

    def push(value)
      while true
        current_head = head
        return self if compare_and_set_head current_head, Node[value, current_head]
      end
    end

    def peek
      head
    end

    def compare_and_pop(head)
      compare_and_set_head head, head.next_node
    end

    def pop
      while true
        current_head = head
        return current_head.value if compare_and_set_head current_head, current_head.next_node
      end
    end

    def compare_and_clear(head)
      compare_and_set_head head, EMPTY
    end

    include Enumerable

    def each(head = nil)
      return to_enum(:each, head) unless block_given?
      it = head || peek
      until it.equal?(EMPTY)
        yield it.value
        it = it.next_node
      end
      self
    end

    def clear
      while true
        current_head = head
        return false if current_head == EMPTY
        return true if compare_and_set_head current_head, EMPTY
      end
    end

    def clear_if(head)
      compare_and_set_head head, EMPTY
    end

    def clear_each(&block)
      while true
        current_head = head
        return self if current_head == EMPTY
        if compare_and_set_head current_head, EMPTY
          each current_head, &block
          return self
        end
      end
    end
  end
end
