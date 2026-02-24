
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM P.CreationDate) ORDER BY P.CreationDate) AS YearRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.UpVotes AS PostUpVotes,
    P.DownVotes AS PostDownVotes,
    P.CommentCount,
    P.YearRank,
    C.CloseReasons
FROM 
    UserVoteSummary U
JOIN 
    PostSummary P ON U.TotalVotes > 5
LEFT JOIN 
    ClosedPostReasons C ON P.PostId = C.PostId
WHERE 
    (P.CommentCount > 10 OR P.YearRank = 1) 
    AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
ORDER BY 
    U.TotalVotes DESC, 
    P.CreationDate DESC
LIMIT 100;
