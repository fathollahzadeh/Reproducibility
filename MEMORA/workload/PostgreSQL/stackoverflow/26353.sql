
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT a.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerName,
        rp.AnswerCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.Rank,
        CASE 
            WHEN rp.AnswerCount >= 10 AND rp.Upvotes - rp.Downvotes > 5 THEN 'Hot'
            WHEN rp.AnswerCount > 5 AND rp.Upvotes - rp.Downvotes > 0 THEN 'Trending'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 100 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    fp.Upvotes,
    fp.Downvotes,
    fp.AnswerCount,
    fp.PostCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC;
