
WITH RankedPosts AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        p.Tags, 
        array_length(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS tag_count,
        COUNT(DISTINCT c.Id) AS comment_count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.Tags, p.ViewCount, p.AnswerCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT
        rp.post_id,
        rp.Title,
        rp.tag_count,
        rp.comment_count,
        rp.upvotes,
        rp.downvotes,
        rp.ViewCount,
        rp.AnswerCount,
        pht.Name AS post_history_type,
        MAX(ph.CreationDate) AS last_edit_date
    FROM
        RankedPosts rp
    LEFT JOIN
        PostHistory ph ON ph.PostId = rp.post_id
    LEFT JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        rp.rank = 1
    GROUP BY 
        rp.post_id, rp.Title, rp.tag_count, rp.comment_count, 
        rp.upvotes, rp.downvotes, rp.ViewCount, rp.AnswerCount, pht.Name
)
SELECT
    fp.Title,
    fp.tag_count,
    fp.comment_count,
    fp.upvotes,
    fp.downvotes,
    fp.ViewCount,
    fp.AnswerCount,
    CASE 
        WHEN fp.ViewCount > 1000 THEN 'High'
        WHEN fp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ViewStatus,
    CASE 
        WHEN fp.comment_count >= 10 THEN 'Highly Engaged'
        WHEN fp.comment_count BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel,
    fp.last_edit_date
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC, 
    fp.comment_count DESC;
