
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyReceived,
        RANK() OVER (ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        COALESCE(cpr.CloseCount, 0) AS CloseCount,
        COALESCE(cpr.CloseReasons, 'No Close Reasons') AS CloseReasons,
        tu.DisplayName AS TopUser,
        tu.TotalBountyReceived
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostReasons cpr ON rp.PostId = cpr.PostId
    LEFT JOIN 
        TopUsers tu ON rp.Score > 0 AND tu.UserRank <= 10
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.CloseCount,
    fp.CloseReasons,
    COALESCE(fp.TopUser, 'No Top User') AS TopUser,
    fp.TotalBountyReceived
FROM 
    FinalPosts fp
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 50;
