
WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>')  
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        AvgUserReputation
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10  
    ORDER BY 
        UpvoteCount DESC
    LIMIT 5
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    m.TagName,
    m.PostCount,
    m.UpvoteCount,
    m.DownvoteCount,
    m.AvgUserReputation,
    pe.PostId,
    pe.Title,
    pe.CommentCount,
    pe.RelatedPostsCount
FROM 
    MostActiveTags m
JOIN 
    PostEngagement pe ON pe.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE CONCAT('%<', m.TagName, '>')  
    )
ORDER BY 
    m.UpvoteCount DESC, 
    pe.CommentCount DESC;
