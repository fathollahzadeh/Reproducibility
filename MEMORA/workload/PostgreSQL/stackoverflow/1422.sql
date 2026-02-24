
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(u.Reputation) AS Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        AVG(u.Reputation) > 100
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ', ') AS CommentsList
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.ViewCount,
        pu.DisplayName,
        pu.Reputation,
        pc.CommentCount,
        pc.CommentsList
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers pu ON rp.OwnerUserId = pu.UserId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.DisplayName AS Author,
    fp.Reputation AS AuthorReputation,
    fp.ViewCount,
    COALESCE(fp.CommentCount, 0) AS TotalComments,
    COALESCE(fp.CommentsList, 'No comments') AS Comments
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC
LIMIT 10;
