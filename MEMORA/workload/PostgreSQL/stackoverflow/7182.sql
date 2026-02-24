WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(u.UpVotes, 0) - COALESCE(u.DownVotes, 0)) AS ReputationScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT v.PostId) > 3
),
PostInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        tu.DisplayName,
        tu.TotalBounties
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.PostId IN (SELECT PostId FROM Votes WHERE UserId = tu.UserId)
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pi.Title,
    pi.Score,
    pi.ViewCount,
    pi.CreationDate,
    pi.DisplayName,
    pi.TotalBounties
FROM 
    PostInfo pi
ORDER BY 
    pi.Score DESC, pi.ViewCount DESC;