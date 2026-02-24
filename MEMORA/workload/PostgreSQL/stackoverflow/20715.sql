WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.CreationDate
),
ActiveUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.LastAccessDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
),
SpamDetection AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(*) AS SpamPosts,
        SUM(CASE WHEN PH.Comment IS NOT NULL AND PH.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate < (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days')
    GROUP BY 
        U.Id
    HAVING 
        COUNT(*) > 10 AND SUM(CASE WHEN PH.Comment IS NOT NULL AND PH.PostHistoryTypeId IN (10, 12) THEN 1 ELSE 0 END) > 5
),
FinalSelection AS (
    SELECT 
        RU.PostId,
        RU.Title,
        RU.OwnerUserId,
        AU.DisplayName AS UserDisplayName,
        AU.Reputation,
        SD.SpamPosts,
        SD.ClosedPosts
    FROM 
        RankedPosts RU
    JOIN 
        ActiveUsers AU ON RU.OwnerUserId = AU.Id
    LEFT JOIN 
        SpamDetection SD ON AU.Id = SD.UserId
    WHERE 
        RU.rn = 1
)
SELECT 
    FS.Title,
    FS.UserDisplayName,
    CASE 
        WHEN FS.SpamPosts IS NULL THEN 'Not spammy'
        WHEN FS.SpamPosts > 5 THEN 'Potential spammer'
        ELSE 'Normal'
    END AS UserStatus,
    FS.Reputation,
    COALESCE(FS.ClosedPosts, 0) AS ClosedPosts
FROM 
    FinalSelection FS
WHERE 
    FS.Reputation BETWEEN 100 AND 1000
ORDER BY 
    FS.Reputation DESC, FS.Title ASC;