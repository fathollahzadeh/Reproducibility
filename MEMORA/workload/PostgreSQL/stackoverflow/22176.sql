
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(V.id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
),
CloseReasonVotes AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CT ON PH.Comment = CAST(CT.Id AS TEXT)
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(RP.PostId, -1) AS LatestPostId,
    COALESCE(RP.Title, 'No Posts Yet') AS LatestPostTitle,
    COALESCE(RP.CreationDate, '1970-01-01') AS LatestPostDate,
    COALESCE(PVC.UpVotes, 0) AS UpVoteCount,
    COALESCE(PVC.DownVotes, 0) AS DownVoteCount,
    COALESCE(PVC.TotalVotes, 0) AS TotalVoteCount,
    COALESCE(CRV.CloseReasons, 'No close reasons') AS CloseReasons,
    COALESCE(UB.BadgeNames, '') AS BadgeNames,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    RankedPosts RP ON U.Id = RP.OwnerUserId AND RP.UserPostRank = 1
LEFT JOIN 
    PostVoteCounts PVC ON RP.PostId = PVC.PostId
LEFT JOIN 
    CloseReasonVotes CRV ON RP.PostId = CRV.PostId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    U.Reputation > 1000 AND 
    (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL)
ORDER BY 
    U.Reputation DESC
LIMIT 50;
