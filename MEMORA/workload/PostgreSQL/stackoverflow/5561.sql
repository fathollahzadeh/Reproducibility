WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory PH ON rp.PostId = PH.PostId
    WHERE 
        rp.rn = 1 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, rp.OwnerDisplayName, PH.PostHistoryTypeId
),
TopBadgedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(B.Id) > 5 
)
SELECT 
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.OwnerDisplayName AS PostOwner,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ps.AnswerCount AS TotalAnswers,
    tub.DisplayName AS BadgedUserName,
    tub.BadgeCount AS NumberOfBadges
FROM 
    PostStatistics ps
JOIN 
    TopBadgedUsers tub ON ps.OwnerDisplayName = tub.DisplayName
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 10;