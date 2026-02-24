
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostCloseReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(crt.Name, ', ') AS CloseReasons
    FROM
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    us.DisplayName,
    us.QuestionCount,
    us.CommentCount,
    us.TotalBounty,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    PCR.CloseReasons
FROM 
    UserStats us
INNER JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    PostCloseReasons PCR ON rp.PostId = PCR.PostId
WHERE 
    us.QuestionCount > 5 
    AND (us.TotalBounty IS NOT NULL OR us.CommentCount > 10)
    AND rp.PostRank = 1
ORDER BY 
    us.TotalBounty DESC, 
    rp.CreationDate DESC
LIMIT 100;
