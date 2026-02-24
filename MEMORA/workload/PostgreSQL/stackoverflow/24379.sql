
WITH DetailedPostStats AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        COALESCE(c.comment_count, 0) AS comment_count,
        COALESCE(v.upvote_count, 0) AS upvote_count,
        COALESCE(v.downvote_count, 0) AS downvote_count,
        COALESCE(ph.history_count, 0) AS history_count,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS type_rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS comment_count 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvote_count
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS history_count 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN (4, 5, 10, 11, 12) 
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
), FilteredPostStats AS (
    SELECT 
        dps.post_id, 
        dps.Title,
        dps.comment_count,
        dps.upvote_count,
        dps.downvote_count,
        dps.history_count,
        ROW_NUMBER() OVER (ORDER BY dps.history_count DESC, dps.upvote_count DESC) AS overall_rank
    FROM 
        DetailedPostStats dps
)
SELECT 
    fps.Title,
    fps.comment_count,
    fps.upvote_count,
    fps.downvote_count,
    fps.history_count,
    CASE 
        WHEN fps.overall_rank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory,
    STRING_AGG(t.TagName, ', ') AS TagsList,
    CASE 
        WHEN fps.history_count > 5 THEN 'Frequent Edits'
        ELSE 'Infrequent Edits'
    END AS EditFrequency
FROM 
    FilteredPostStats fps
LEFT JOIN (
        SELECT 
            t.TagName, fps.Title
        FROM 
            Tags t
        CROSS JOIN 
            (SELECT DISTINCT Title FROM FilteredPostStats) AS Titles
        WHERE 
            Titles.Title = t.TagName
    ) AS t ON true
GROUP BY 
    fps.post_id, fps.Title, fps.comment_count, fps.upvote_count, 
    fps.downvote_count, fps.history_count, fps.overall_rank
ORDER BY 
    fps.overall_rank;
