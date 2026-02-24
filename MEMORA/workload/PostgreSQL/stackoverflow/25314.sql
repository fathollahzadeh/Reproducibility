
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent'
            WHEN rp.Rank <= 5 THEN 'Top 5 Recent'
            ELSE 'Other'
        END AS RankCategory,
        LENGTH(rp.Body) AS BodyLength,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Badges b ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Rank, rp.Body
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        SUM(CASE WHEN pt.Title IS NOT NULL THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Title IS NULL THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.RankCategory,
    ps.BodyLength,
    ps.CommentCount,
    ps.VoteCount,
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount
FROM 
    PostStatistics ps
LEFT JOIN 
    TagStats ts ON ps.Title LIKE '%' || ts.TagName || '%'
WHERE 
    ps.BodyLength > 100 AND ps.VoteCount > 0
ORDER BY 
    ps.VoteCount DESC, ps.BodyLength DESC;
