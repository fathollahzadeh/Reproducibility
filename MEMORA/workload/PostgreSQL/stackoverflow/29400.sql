
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        LOWER(t.TagName) AS ProcessedTagName
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON true
), TagMetrics AS (
    SELECT 
        PostId,
        ProcessedTagName,
        COUNT(PostId) AS TagFrequency
    FROM 
        ProcessedTags
    GROUP BY 
        PostId, ProcessedTagName
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tm.ProcessedTagName,
    tm.TagFrequency,
    ue.DisplayName AS UserAuthor,
    ue.UpVotesReceived,
    ue.DownVotesReceived,
    ue.CommentsMade
FROM 
    TopPosts tp
JOIN 
    TagMetrics tm ON tp.PostId = tm.PostId
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.Score DESC, 
    tm.TagFrequency DESC;
