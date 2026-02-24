
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
PostDetail AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        COALESCE(PAC.TotalVotes, 0) AS PostTotalVotes,
        COALESCE(PAC.UpVotes, 0) AS PostUpVotes,
        COALESCE(PAC.DownVotes, 0) AS PostDownVotes,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY COALESCE(PAC.TotalVotes, 0) DESC) AS VoteRank
    FROM 
        Posts P
    LEFT JOIN 
        PostVoteCounts PAC ON P.Id = PAC.PostId
)
SELECT 
    UVC.UserId,
    UVC.DisplayName,
    SUM(PD.PostTotalVotes) AS TotalVotesForUser,
    AVG(PD.PostUpVotes) AS AvgUpVotes,
    AVG(PD.PostDownVotes) AS AvgDownVotes,
    (SELECT COUNT(DISTINCT B.Id) 
     FROM Badges B 
     WHERE B.UserId = UVC.UserId AND B.Class = 1) AS GoldBadges,
    (SELECT COUNT(DISTINCT B.Id) 
     FROM Badges B 
     WHERE B.UserId = UVC.UserId AND B.Class = 2) AS SilverBadges,
    (SELECT COUNT(DISTINCT B.Id) 
     FROM Badges B 
     WHERE B.UserId = UVC.UserId AND B.Class = 3) AS BronzeBadges
FROM 
    UserVoteCounts UVC
JOIN 
    PostDetail PD ON UVC.UserId = PD.Id
WHERE 
    UVC.TotalVotes > 100
GROUP BY 
    UVC.UserId, UVC.DisplayName
HAVING 
    SUM(PD.PostTotalVotes) > 200
ORDER BY 
    TotalVotesForUser DESC;
