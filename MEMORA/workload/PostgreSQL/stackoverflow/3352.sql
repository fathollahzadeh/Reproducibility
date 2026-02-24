
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS HistoryTypeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND TIMESTAMP '2024-10-01 12:34:56'
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    COALESCE(phc.HistoryTypeCount, 0) AS PostHistoryCount,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
JOIN 
    TopUsers tu ON tu.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = rp.PostId
        ORDER BY CreationDate DESC
        LIMIT 1
    )
WHERE 
    rp.UserPostRank = 1
    AND rp.Score > 10
    AND rp.ViewCount > (
        SELECT AVG(ViewCount) 
        FROM Posts 
        WHERE PostTypeId = 1
    )
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 100;
