shared_examples 'token_authenticatable' do
  describe '.find_by_authentication_token' do
    context 'valid token' do
      it 'finds correct user' do
        class_symbol = described_class.name.underscore
        item = create(class_symbol, :authentication_token)
        create(class_symbol, :authentication_token)

        item_found = described_class.find_by_authentication_token(
          item.authentication_token
        )

        expect(item_found).to eq item
      end
    end

    context 'nil token' do
      it 'returns nil' do
        class_symbol = described_class.name.underscore
        create(class_symbol)

        item_found = described_class.find_by_authentication_token(nil)

        expect(item_found).to be_nil
      end
    end
  end

  describe '#ensure_authentication_token' do
    it 'creates auth token' do
      class_symbol = described_class.name.underscore
      item = create(class_symbol, authentication_token: '')

      item.ensure_authentication_token

      expect(item.authentication_token).not_to be_blank
    end
  end

  describe '#reset_authentication_token!' do
    it 'resets auth token' do
    end
  end
end