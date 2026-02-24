WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts AS p
    LEFT JOIN 
        Posts AS a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users AS u
    LEFT JOIN 
        Badges AS b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalClose,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopen
    FROM 
        PostHistory AS ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ur.TotalBadges,
        ur.TotalReputation,
        COALESCE(phs.TotalClose, 0) AS TotalClose,
        COALESCE(phs.TotalReopen, 0) AS TotalReopen
    FROM 
        RankedPosts AS rp
    JOIN 
        UserReputation AS ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistoryStats AS phs ON rp.PostId = phs.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    TotalBadges,
    TotalReputation,
    TotalClose,
    TotalReopen
FROM 
    FinalResults
WHERE 
    (TotalBadges > 0 OR TotalReputation > 100) 
AND 
    (Score > 5 OR AnswerCount > 3) 
ORDER BY 
    Score DESC, ViewCount DESC;