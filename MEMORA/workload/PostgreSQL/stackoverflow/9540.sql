
WITH PopularQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Owner,
        P.ViewCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount
    HAVING 
        COUNT(A.Id) > 0 AND P.ViewCount > 1000
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 ELSE NULL END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 ELSE NULL END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (10, 11) THEN 1 ELSE NULL END) AS CloseReopenCount
    FROM 
        Votes 
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        PQ.PostId,
        PQ.Title,
        PQ.Owner,
        PQ.ViewCount,
        PQ.AnswerCount,
        PQ.UpVotes,
        PQ.DownVotes,
        COALESCE(VS.UpVotes, 0) AS CumulativeUpVotes,
        COALESCE(VS.DownVotes, 0) AS CumulativeDownVotes,
        COALESCE(VS.CloseReopenCount, 0) AS CloseReopenCount
    FROM 
        PopularQuestions PQ
    LEFT JOIN 
        VoteSummary VS ON PQ.PostId = VS.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Owner,
    TP.ViewCount,
    TP.AnswerCount,
    (TP.UpVotes + TP.CumulativeUpVotes) AS TotalUpVotes,
    (TP.DownVotes + TP.CumulativeDownVotes) AS TotalDownVotes,
    TP.CloseReopenCount,
    ((TP.UpVotes + TP.CumulativeUpVotes) - (TP.DownVotes + TP.CumulativeDownVotes)) AS VoteBalance
FROM 
    TopPosts TP
ORDER BY 
    VoteBalance DESC, TP.ViewCount DESC
LIMIT 10;
