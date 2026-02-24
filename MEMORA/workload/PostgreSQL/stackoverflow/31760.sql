WITH RecursiveTagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count AS TagCount,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY T.Id ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1  
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostedQuestions,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentsMade,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 0  
)
SELECT 
    R.TagId,
    R.TagName,
    R.TagCount,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    P.UpVoteCount,
    P.DownVoteCount,
    P.TotalVotes,
    A.UserId,
    A.DisplayName,
    A.PostedQuestions,
    A.CommentsMade,
    A.LastPostDate
FROM 
    RecursiveTagStats R
LEFT JOIN 
    PostVoteStats P ON R.PostId = P.PostId
LEFT JOIN 
    RecentActivity A ON R.PostId = A.PostedQuestions
WHERE 
    R.RecentPostRank = 1  
ORDER BY 
    R.TagCount DESC, R.Score DESC;