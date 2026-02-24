WITH PostStats AS (
    SELECT 
        p.Id AS post_id,
        p.Title AS post_title,
        p.CreationDate AS post_creation_date,
        COUNT(c.Id) AS comment_count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvote_count,
        COUNT(DISTINCT b.Id) AS badge_count,
        MAX(ph.CreationDate) AS last_edit_date
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
), RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.upvote_count DESC, ps.comment_count DESC) AS rank
    FROM 
        PostStats ps
)
SELECT 
    rp.post_id,
    rp.post_title,
    rp.post_creation_date,
    rp.comment_count,
    rp.upvote_count,
    rp.downvote_count,
    rp.badge_count,
    rp.last_edit_date,
    CASE 
        WHEN rp.rank <= 10 THEN 'Top 10'
        WHEN rp.rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS rank_category
FROM 
    RankedPosts rp
ORDER BY 
    rp.rank;