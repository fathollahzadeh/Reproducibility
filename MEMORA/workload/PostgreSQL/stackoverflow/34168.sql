
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        RANK() OVER (ORDER BY SUM(v.BountyAmount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    ph.EditCount,
    ph.LastEditDate,
    tu.UserId,
    tu.DisplayName AS TopUser,
    tu.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCTE ph ON rp.Id = ph.PostId
LEFT JOIN 
    TopUsers tu ON tu.UserRank = 1 
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC
LIMIT 10;
