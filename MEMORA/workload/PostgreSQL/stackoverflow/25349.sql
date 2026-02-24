
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS RankByComments,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByRecency
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.PostTypeId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.RankByComments,
        rp.RankByRecency,
        CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation, ')') AS UserInfo
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    WHERE 
        rp.RankByComments <= 10 OR rp.RankByRecency <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.UserInfo,
    fp.CommentCount,
    fp.AnswerCount,
    fp.Upvotes,
    fp.Downvotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CommentCount DESC, 
    fp.Upvotes DESC;
