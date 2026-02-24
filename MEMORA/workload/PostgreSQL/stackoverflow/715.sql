WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(UPV.UpVotes, 0) AS UpVotes,
        COALESCE(DNV.DownVotes, 0) AS DownVotes,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN UserVotes UPV ON P.OwnerUserId = UPV.UserId
    LEFT JOIN UserVotes DNV ON P.OwnerUserId = DNV.UserId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerUserId,
        PD.UpVotes,
        PD.DownVotes,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        PD.PostRank,
        ROW_NUMBER() OVER (ORDER BY PD.UpVotes DESC, PD.ViewCount DESC) AS OverallRank
    FROM PostDetails PD
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    RP.UpVotes,
    RP.DownVotes,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    RP.OverallRank
FROM RankedPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
WHERE RP.OverallRank <= 10
ORDER BY RP.OverallRank;