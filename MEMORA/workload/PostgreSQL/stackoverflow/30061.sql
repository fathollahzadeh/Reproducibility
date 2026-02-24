WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS pn_rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(u.DownVotes, 0)) AS TotalDownVotes,
        ROW_NUMBER() OVER(ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER(ORDER BY COUNT(c.Id) DESC) AS ActiveRank
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.UserRank,
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    ap.PostId,
    ap.Title,
    ap.CreationDate AS QuestionCreationDate,
    cp.FirstClosedDate,
    au.CommentCount,
    au.TotalBounty,
    CASE 
        WHEN cp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopUsers tu
JOIN 
    RankedPosts ap ON tu.UserId = ap.OwnerUserId AND ap.pn_rank = 1
LEFT JOIN 
    ClosedPosts cp ON ap.PostId = cp.PostId
JOIN 
    ActiveUsers au ON tu.UserId = au.UserId
WHERE 
    tu.UserRank <= 10 
ORDER BY 
    tu.UserRank;