App.ApplianceType = DS.Model.extend
  name: DS.attr('string')
  description: DS.attr('string')
  shared: DS.attr('boolean')
  scalable: DS.attr('boolean')
  visibility: DS.attr('string')
  author: DS.belongsTo('user')

  published: (->
    @get('visibility') == 'published'
  ).property 'visibility'

  author_name: (->
    if @get('author') == null
      'anonymous'
    else
      @get('author.login')
  ).property 'author.login'
