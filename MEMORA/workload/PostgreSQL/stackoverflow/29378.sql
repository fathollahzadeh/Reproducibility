
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = pl.RelatedPostId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, p.CreationDate
),

UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        RANK() OVER (ORDER BY SUM(rp.TotalUpvotes) - SUM(rp.TotalDownvotes) DESC) AS UserRank
    FROM 
        Users u
    INNER JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.UserRank,
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CommentCount,
    rp.AnswerCount,
    rp.TotalUpvotes,
    rp.TotalDownvotes
FROM 
    UserRankings ur
JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE 
    ur.UserRank <= 10  
ORDER BY 
    ur.UserRank, rp.CreationDate DESC;
