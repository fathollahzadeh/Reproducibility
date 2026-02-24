
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.Score AS PostScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.Score, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (UPPER(rp.Title) LIKE '%SQL%') AS ContainsSQL,
        (UPPER(rp.Body) LIKE '%STRING%') AS ContainsString
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
),
AggregatedResults AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN ContainsSQL THEN 1 ELSE 0 END) AS PostsWithSQL,
        SUM(CASE WHEN ContainsString THEN 1 ELSE 0 END) AS PostsWithString,
        AVG(PostScore) AS AvgPostScore
    FROM 
        FilteredPosts
)

SELECT 
    * 
FROM 
    AggregatedResults;
