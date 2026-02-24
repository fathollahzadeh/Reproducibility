
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        u.DisplayName AS AuthorName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
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
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1), u.DisplayName
),
AggregatedResults AS (
    SELECT 
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC, TagCount DESC) AS Rank,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.AuthorName,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
)
SELECT 
    *,
    CONCAT('Post Title: ', Title, ' | Author: ', AuthorName, ' | Views: ', ViewCount, ' | Score: ', Score, ' | Comments: ', CommentCount, ' | Score Category: ', ScoreCategory) AS PostSummary
FROM 
    AggregatedResults
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
