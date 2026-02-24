
WITH RankedPosts AS (
    SELECT 
        p.Id AS post_id,
        p.Title AS post_title,
        p.Body AS post_body,
        p.CreationDate AS post_creation_date,
        COUNT(v.Id) AS vote_count,
        STRING_AGG(t.TagName, ', ') AS tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
), FilteredPosts AS (
    SELECT 
        post_id,
        post_title,
        post_body,
        post_creation_date,
        vote_count,
        tags,
        RANK() OVER (ORDER BY vote_count DESC, post_creation_date DESC) AS rnk
    FROM 
        RankedPosts
    WHERE 
        vote_count > 0  
)
SELECT 
    fp.post_id,
    fp.post_title,
    fp.vote_count,  -- corrected from votes_count to vote_count
    fp.tags,
    CONCAT('<div>', SUBSTRING(fp.post_body, 1, 200), '...</div>') AS excerpt,
    (SELECT STRING_AGG(DISTINCT u.DisplayName, ', ')
     FROM Users u 
     JOIN Comments c ON c.PostId = fp.post_id
     WHERE c.UserId = u.Id) AS commenters,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = fp.post_id AND ph.PostHistoryTypeId = 10) THEN 'Closed'
        ELSE 'Open'
    END AS post_status
FROM 
    FilteredPosts fp
WHERE 
    fp.rnk <= 10  
ORDER BY 
    fp.rnk;
