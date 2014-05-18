shared_examples 'childhoodable' do
  context '.old?' do
    it 'is not old for new created objects' do
      vm = build(:virtual_machine, created_at: Time.now)

      expect(vm.old?).to be_false
    end

    it 'is old when created before 5 minutes' do
      vm = build(:virtual_machine, created_at: 6.minutes.ago)

      expect(vm.old?).to be_true
    end
  end
end