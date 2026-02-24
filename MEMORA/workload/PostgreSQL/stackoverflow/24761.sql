WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.OwnerUserId) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.OwnerUserId) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), 
CloseReasonCounts AS (
    SELECT 
        PH.UserId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.UserId, 
        PH.PostHistoryTypeId
), 
MergedStats AS (
    SELECT 
        R.OwnerUserId,
        COUNT(R.PostId) AS TotalPosts,
        SUM(CASE WHEN R.PostRank = 1 THEN 1 ELSE 0 END) AS TopPosts,
        U.GoldCount,
        U.SilverCount,
        U.BronzeCount,
        COALESCE(CC.CloseCount, 0) AS TotalCloseVotes
    FROM 
        RankedPosts R
    JOIN 
        UserBadges U ON R.OwnerUserId = U.UserId
    LEFT JOIN 
        CloseReasonCounts CC ON R.OwnerUserId = CC.UserId
    GROUP BY 
        R.OwnerUserId, U.GoldCount, U.SilverCount, U.BronzeCount, CC.CloseCount
)
SELECT 
    M.OwnerUserId,
    M.TotalPosts,
    M.TopPosts,
    M.GoldCount,
    M.SilverCount,
    M.BronzeCount,
    M.TotalCloseVotes,
    CASE
        WHEN M.TotalPosts > 100 THEN 'Veteran'
        WHEN M.TotalPosts > 50 THEN 'Experienced'
        ELSE 'Newcomer'
    END AS UserCategory
FROM 
    MergedStats M
WHERE 
    M.TotalPosts > (SELECT AVG(TotalPosts) FROM MergedStats) 
ORDER BY 
    M.TotalPosts DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;