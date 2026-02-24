
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score >= 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        AVG(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE NULL END) OVER (PARTITION BY ph.PostId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '5 years'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100
),
ActiveUsers AS (
    SELECT 
        u.Id,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 months'
    GROUP BY 
        u.Id
),
FinalSelection AS (
    SELECT 
        u.Id,
        u.DisplayName,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        COALESCE(cp.CloseCount, 0) AS TotalClosedPosts,
        au.ActivePostCount
    FROM 
        TopUsers u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    JOIN 
        ActiveUsers au ON u.Id = au.Id
    WHERE 
        rp.rn = 1  
)
SELECT 
    fs.DisplayName,
    fs.Title,
    fs.CreationDate,
    fs.Score,
    CASE 
        WHEN fs.ActivePostCount > 10 THEN 'Highly Active User'
        WHEN fs.ActivePostCount BETWEEN 5 AND 10 THEN 'Moderately Active User'
        ELSE 'Less Active User' 
    END AS ActivityLevel,
    fs.TotalClosedPosts
FROM 
    FinalSelection fs
ORDER BY 
    fs.Score DESC, 
    fs.TotalClosedPosts DESC
LIMIT 50;
