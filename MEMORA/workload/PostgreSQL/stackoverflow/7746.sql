WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes, 
        DownVotes, 
        PostCount, 
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY UpVotes - DownVotes DESC) AS Rank
    FROM 
        UserVoteStatistics
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COUNT(V.Id) AS VoteCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount
    HAVING 
        COUNT(V.Id) > 5
),
AggregatedData AS (
    SELECT 
        U.Rank,
        U.DisplayName AS UserDisplayName,
        P.Title AS PostTitle,
        P.ViewCount,
        P.VoteCount,
        P.CommentCount
    FROM 
        TopUsers U
    CROSS JOIN 
        TopPosts P
    WHERE 
        U.Rank <= 10
)
SELECT 
    AD.UserDisplayName,
    AD.PostTitle,
    AD.ViewCount,
    AD.VoteCount,
    AD.CommentCount
FROM 
    AggregatedData AD
ORDER BY 
    AD.VoteCount DESC, AD.ViewCount DESC;
