WITH RankedComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.UserId,
        u.DisplayName AS UserDisplayName,
        c.Score,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM Comments c
    JOIN Users u ON c.UserId = u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        p.PostTypeId,
        (SELECT COUNT(*) FROM RankedComments rc WHERE rc.PostId = p.Id AND rc.CommentRank <= 5) AS RecentCommentCount
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(pt.Id) DESC) AS TagRank
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AnswerCount,
    rp.ViewCount,
    rp.RecentCommentCount,
    tt.TagName,
    tt.PostCount AS TagUsageCount
FROM RecentPosts rp
LEFT JOIN TopTags tt ON tt.TagRank = 1  
WHERE rp.PostTypeId = 1  
ORDER BY rp.ViewCount DESC, rp.RecentCommentCount DESC
LIMIT 10;