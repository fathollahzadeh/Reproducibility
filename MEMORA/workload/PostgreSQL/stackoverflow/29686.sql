
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(b.Class) AS AvgBadgeClass
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, 
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1), u.DisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        Score,
        TagCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        AvgBadgeClass,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    Rank,
    Title,
    ViewCount,
    AnswerCount,
    Score,
    TagCount,
    OwnerDisplayName,
    CommentCount,
    UpVotes,
    DownVotes,
    AvgBadgeClass
FROM 
    RankedPosts
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
