
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST(CAST('2024-10-01' AS DATE) - INTERVAL '30 days' AS DATE)
        AND p.PostTypeId IN (1, 2)
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.Comment IS NOT NULL THEN 
                CONCAT('Reason: ', crt.Name, ' by ', ph.UserDisplayName) 
            ELSE 'Closed without reason' END, '; ') AS CloseReasons 
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        CASE 
            WHEN ur.Reputation IS NULL THEN 0 
            ELSE ur.Reputation + ur.TotalBounty 
        END AS UserReputation
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.UserRank = 1
),
FinalResults AS (
    SELECT 
        pm.Title,
        pm.CreationDate,
        pm.Score AS PostScore,
        pm.ViewCount,
        pm.AnswerCount,
        COALESCE(cpr.CloseReasons, 'Not Closed') AS PostCloseReasons,
        pm.UserReputation,
        CASE 
            WHEN pm.UserReputation > 1000 THEN 'Active User'
            WHEN pm.UserReputation BETWEEN 500 AND 1000 THEN 'Moderate User'
            ELSE 'New User'
        END AS UserStatus
    FROM 
        PostMetrics pm
    LEFT JOIN 
        ClosedPostReasons cpr ON pm.PostId = cpr.PostId
)

SELECT 
    F.*,
    CASE 
        WHEN F.PostCloseReasons IS NOT NULL AND F.PostCloseReasons <> '' THEN TRUE 
        ELSE FALSE 
    END AS HasCloseReason
FROM 
    FinalResults F
WHERE 
    F.UserReputation > 0
ORDER BY 
    F.PostScore DESC, 
    F.ViewCount DESC
LIMIT 100;
