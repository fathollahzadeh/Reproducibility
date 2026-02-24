
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(C.Id) DESC) AS UserRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.TotalComments,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        RankedPosts RP
    WHERE 
        RP.UserRank <= 5
)
SELECT 
    UP.Id AS UserId,
    UP.DisplayName,
    TP.Title,
    TP.TotalComments,
    TP.UpVotes,
    TP.DownVotes
FROM 
    Users UP
JOIN 
    TopPosts TP ON UP.Id = TP.PostId
ORDER BY 
    TP.UpVotes DESC, 
    TP.TotalComments DESC;
