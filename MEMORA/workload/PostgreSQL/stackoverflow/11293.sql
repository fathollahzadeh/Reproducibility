
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag_name ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.AnswerCount, p.CommentCount
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.LastAccessDate DESC) AS Rank
    FROM 
        Users u
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.Text,
        c.CreationDate,
        c.UserId,
        u.DisplayName AS UserDisplayName,
        ROW_NUMBER() OVER (ORDER BY c.CreationDate DESC) AS Rank
    FROM 
        Comments c
    JOIN 
        Users u ON c.UserId = u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    ru.UserId AS RecentUserId,
    ru.DisplayName AS RecentUserName,
    ru.Reputation AS RecentUserReputation,
    rc.CommentId,
    rc.Text AS RecentCommentText,
    rc.CreationDate AS RecentCommentDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUsers ru ON ru.Rank <= 10
LEFT JOIN 
    RecentComments rc ON rc.PostId = rp.PostId AND rc.Rank <= 5
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.ViewCount DESC, rc.CreationDate DESC;
