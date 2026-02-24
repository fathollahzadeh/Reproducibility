
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, CreationDate, Score, CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, TotalBounty, UpVotes, TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    tp.PostId,
    tp.Title AS PostTitle,
    tp.ViewCount,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tu.DisplayName AS UserName,
    tu.TotalPosts,
    tu.TotalBounty,
    tu.UpVotes
FROM 
    TopPosts tp
JOIN
    TopUsers tu ON tp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
WHERE 
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = tp.PostId
        AND v.UserId = tu.UserId
        AND v.VoteTypeId = 2  
    )
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
