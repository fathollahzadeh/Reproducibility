WITH PostVoteCount AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserPostsStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(PVC.VoteCount), 0) AS TotalVotes,
        COALESCE(SUM(PVC.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(PVC.DownVotes), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostVoteCount PVC ON P.Id = PVC.PostId
    GROUP BY 
        U.Id
),
UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
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
    COALESCE(UPS.PostCount, 0) AS PostCount,
    COALESCE(UPS.TotalVotes, 0) AS TotalVotes,
    COALESCE(UPS.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(UPS.TotalDownVotes, 0) AS TotalDownVotes,
    COALESCE(UBS.BadgeCount, 0) AS BadgeCount,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate
FROM 
    Users U
LEFT JOIN 
    UserPostsStats UPS ON U.Id = UPS.UserId
LEFT JOIN 
    UserBadgeStats UBS ON U.Id = UBS.UserId
ORDER BY 
    U.Reputation DESC;