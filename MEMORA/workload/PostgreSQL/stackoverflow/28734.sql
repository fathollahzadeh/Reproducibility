
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        COALESCE(a.Body, '') AS AcceptedAnswerBody,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS CommentCount 
         FROM 
             Comments 
         GROUP BY 
             PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
PostEngagement AS (
    SELECT 
        fp.PostId,
        fp.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty,
        fp.ViewCount,
        fp.Score,
        ts.PostCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        TagStatistics ts ON ts.TagName = ANY(string_to_array(fp.Tags, '><'))
    GROUP BY 
        fp.PostId, fp.Title, fp.ViewCount, fp.Score, ts.PostCount
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.TotalComments,
    pe.TotalBounty,
    pe.ViewCount,
    pe.Score,
    pe.PostCount,
    ROUND((100.0 * pe.TotalComments / NULLIF(pe.ViewCount, 0)), 2) AS CommentRatio,
    ROUND((100.0 * pe.Score / NULLIF(pe.ViewCount, 0)), 2) AS ScoreRatio
FROM 
    PostEngagement pe
ORDER BY 
    pe.Score DESC, pe.TotalComments DESC
LIMIT 50;
