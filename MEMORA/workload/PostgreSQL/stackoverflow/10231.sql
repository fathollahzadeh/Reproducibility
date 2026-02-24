
WITH PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalViews,
    U.TotalScore,
    U.LastPostDate,
    PVC.PostId,
    PVC.VoteCount,
    PVC.UpVotes,
    PVC.DownVotes
FROM 
    UserPostStats U
LEFT JOIN 
    PostVoteCounts PVC ON PVC.PostId = U.UserId
ORDER BY 
    U.TotalScore DESC, U.PostCount DESC
LIMIT 100;
