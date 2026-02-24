
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.ANSWERCOUNT,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1  
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),

UserParticipations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvotesReceived,
        COUNT(CASE WHEN c.UserId IS NOT NULL THEN 1 END) AS CommentsReceived
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
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    ts.TagName,
    ts.TagCount,
    up.DisplayName AS ActiveUser,
    up.UpvotesReceived,
    up.CommentsReceived
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
JOIN 
    UserParticipations up ON rp.OwnerDisplayName = up.DisplayName
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
