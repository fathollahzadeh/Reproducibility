
WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.AnswerCount,
        RP.UpVotes,
        RP.DownVotes
    FROM 
        RankedPosts RP
    WHERE 
        RP.rn = 1
    ORDER BY 
        RP.CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS RecentVoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        V.PostId
),
PostsWithRecentVotes AS (
    SELECT 
        TP.*,
        COALESCE(RV.RecentVoteCount, 0) AS RecentVoteCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        RecentVotes RV ON TP.Id = RV.PostId
),
ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        PH.CreationDate
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        P.Id, P.Title, PH.CreationDate
)
SELECT 
    P.Title AS "Post Title",
    P.OwnerDisplayName AS "Posted By",
    P.CreationDate AS "Creation Date",
    P.AnswerCount AS "Answer Count",
    P.UpVotes AS "Up Votes",
    P.DownVotes AS "Down Votes",
    P.RecentVoteCount AS "Recent Votes",
    CASE WHEN CP.Id IS NOT NULL THEN 'Yes' ELSE 'No' END AS "Is Closed"
FROM 
    PostsWithRecentVotes P
LEFT JOIN 
    ClosedPosts CP ON P.Id = CP.Id
ORDER BY 
    P.RecentVoteCount DESC, 
    P.CreationDate DESC;
