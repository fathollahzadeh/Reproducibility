
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.CommentCount,
        RP.VoteCount,
        ROW_NUMBER() OVER (ORDER BY RP.Score DESC, RP.ViewCount DESC) AS Rank
    FROM 
        RankedPosts RP
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.CommentCount,
    TP.VoteCount,
    AU.DisplayName,
    AU.PostsCount,
    AU.TotalUpVotes,
    AU.TotalDownVotes
FROM 
    TopPosts TP
JOIN 
    ActiveUsers AU ON TP.PostId IN (SELECT DISTINCT P.Id FROM Posts P WHERE P.OwnerUserId = AU.UserId)
WHERE 
    TP.Rank <= 10 
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
